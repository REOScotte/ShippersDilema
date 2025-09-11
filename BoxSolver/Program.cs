using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

class Program
{
    static int Xsize = 5;
    static int Ysize = 5;
    static int Zsize = 5;

    static int[] pieces = { 3, 1, 1, 13 };
    static string[] shapes = { "113", "122", "222", "124" };
    static string startSequence = "";
    static int totalSolutions = 0;

    static ulong counter = 0;
    static List<string> sequence = new List<string>();
    static List<List<string>> orientations = new List<List<string>>();
    static List<string> solutions = new List<string>();
    static int totalPieces = pieces.Sum();
    static int[,,] box = new int[Xsize, Ysize, Zsize];

    static void Main()
    {
        foreach (var shape in shapes)
        {
            var perms = GetPermutations(shape).Distinct().ToList();
            orientations.Add(perms);
        }

        var startPieces = startSequence.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
        foreach (var startPiece in startPieces)
        {
            for (int i = 0; i < orientations.Count; i++)
            {
                if (orientations[i].Contains(startPiece))
                {
                    pieces[i]--;
                    sequence.Add(startPiece);
                }
            }
        }

        string currentShape;
        if (sequence.Count > 0)
        {
            currentShape = sequence.Last();
            sequence.RemoveAt(sequence.Count - 1);
            for (int i = 0; i < orientations.Count; i++)
            {
                if (orientations[i].Contains(currentShape)) pieces[i]++;
            }
        }
        else
        {
            currentShape = orientations[0][0];
        }

        var sw = Stopwatch.StartNew();

        while (!string.IsNullOrEmpty(currentShape))
        {
            counter++;
            sequence.Add(currentShape);

            for (int i = 0; i < orientations.Count; i++)
            {
                if (orientations[i].Contains(currentShape)) pieces[i]--;
            }

            if (TestSequence())
            {
                if (sequence.Count == totalPieces)
                {
                    totalSolutions++;
                    string solution = $"{string.Join(" ", sequence)},{counter},{DateTime.Now}";
                    solutions.Add(solution);
                    File.AppendAllText("solutions.csv", solution + Environment.NewLine);
                    sequence.RemoveAt(sequence.Count - 1);
                    Console.WriteLine($"Total Solutions: {totalSolutions}, Current Solution: {solution}");
                }
                else
                {
                    currentShape = "000";
                }
            }
            else
            {
                sequence.RemoveAt(sequence.Count - 1);
            }

            string nextShape = null;
            do
            {
                for (int i = 0; i < orientations.Count; i++)
                {
                    if (orientations[i].Contains(currentShape)) pieces[i]++;
                }

                List<string> availableOrientations = new List<string>();
                for (int i = 0; i < pieces.Length; i++)
                {
                    if (pieces[i] > 0)
                    {
                        availableOrientations.AddRange(orientations[i]);
                    }
                }

                int nextIndex = availableOrientations.IndexOf(currentShape) + 1;
                if (nextIndex < availableOrientations.Count)
                {
                    nextShape = availableOrientations[nextIndex];
                }
                else
                {
                    if (sequence.Count > 0)
                    {
                        currentShape = sequence.Last();
                        sequence.RemoveAt(sequence.Count - 1);
                    }
                    else
                    {
                        currentShape = null;
                    }
                }
            } while (nextShape == null && !(sequence.Count == 0 && currentShape == orientations.Last().Last()));

            currentShape = nextShape;
        }

        Console.WriteLine($"Elapsed time: {sw.Elapsed.TotalSeconds} seconds");
    }

    static IEnumerable<string> GetPermutations(string str)
    {
        if (str.Length <= 1)
        {
            yield return str;
        }
        else
        {
            for (int i = 0; i < str.Length; i++)
            {
                var ch = str[i];
                var rest = str.Substring(0, i) + str.Substring(i + 1);
                foreach (var perm in GetPermutations(rest))
                {
                    yield return ch + perm;
                }
            }
        }
    }

    static bool TestSequence()
    {
        Array.Clear(box, 0, box.Length);

        foreach (var piece in sequence)
        {
            bool found = false;
            int ex = 0, ey = 0, ez = 0;

            for (int z = 0; z < Zsize && !found; z++)
            {
                for (int y = 0; y < Ysize && !found; y++)
                {
                    for (int x = 0; x < Xsize && !found; x++)
                    {
                        if (box[x, y, z] == 0)
                        {
                            ex = x; ey = y; ez = z;
                            found = true;
                        }
                    }
                }
            }

            int px = int.Parse(piece[0].ToString());
            int py = int.Parse(piece[1].ToString());
            int pz = int.Parse(piece[2].ToString());

            for (int z = ez; z < ez + pz; z++)
            {
                for (int y = ey; y < ey + py; y++)
                {
                    for (int x = ex; x < ex + px; x++)
                    {
                        if (x >= Xsize || y >= Ysize || z >= Zsize || box[x, y, z] != 0)
                            return false;
                        box[x, y, z] = 1;
                    }
                }
            }
        }

        return true;
    }
}
