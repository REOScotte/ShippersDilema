using System;
using System.Collections.Generic;
using System.Diagnostics;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace CubePacking
{
    class Program
    {
        static Random rng = new Random();
        static int[,,] cube = new int[5, 5, 5];
        static int bestSoFar = 0;

        static void Main()
        {
            Stopwatch globalTimer = Stopwatch.StartNew();

            while (true)
            {
                ClearCube();
                List<Placement> placedPieces = new List<Placement>();

                // First place all large (2x2x3)
                if (!PlacePieces("Large", 6, placedPieces)) { FailAndRestart(); continue; }

                // Then place all medium (1x2x4)
                if (!PlacePieces("Medium", 6, placedPieces)) { FailAndRestart(); continue; }

                // Finally, place all small (1x1x1)
                if (!PlaceSmall(5, placedPieces)) { FailAndRestart(); continue; }

                // If we reach here, all 17 placed
                globalTimer.Stop();
                Console.Clear();
                Console.WriteLine("=== SOLUTION FOUND ===\n");
                foreach (var piece in placedPieces)
                    Console.WriteLine(piece);

                var elapsed = globalTimer.Elapsed;
                Console.WriteLine($"\nElapsed: {elapsed.Days}d {elapsed.Hours}h {elapsed.Minutes}m");

                //Console.WriteLine("Press a key to continue.");
                //Console.ReadKey();

                return; // stop program
            }
        }

        static void FailAndRestart()
        {
            //Console.Clear();
            //Console.WriteLine($"Max placed so far: {bestSoFar}");
            //bestSoFar = 0;
        }

        static bool PlacePieces(string type, int count, List<Placement> placed)
        {
            for (int i = 0; i < count; i++)
            {
                Piece piece = Piece.Create(type);
                if (!TryPlacePiece(piece, placed))
                    return false;

                if (placed.Count > bestSoFar)
                {
                    bestSoFar = placed.Count;
                    Console.WriteLine($"Max placed so far: {bestSoFar}");
                }
            }
            return true;
        }

        static bool PlaceSmall(int count, List<Placement> placed)
        {
            for (int i = 0; i < count; i++)
            {
                // just pick any empty space
                var empty = FindEmpty();
                if (empty == null) return false;

                var (x, y, z) = empty.Value;
                cube[x, y, z] = 1;
                placed.Add(new Placement("Small", x, y, z, "1x1x1"));
                if (placed.Count > bestSoFar) bestSoFar = placed.Count;
                Console.Beep();
            }
            return true;
        }

        static (int, int, int)? FindEmpty()
        {
            List<(int, int, int)> empties = new List<(int, int, int)>();
            for (int x = 0; x < 5; x++)
                for (int y = 0; y < 5; y++)
                    for (int z = 0; z < 5; z++)
                        if (cube[x, y, z] == 0) empties.Add((x, y, z));

            if (empties.Count == 0) return null;
            return empties[rng.Next(empties.Count)];
        }

        static bool TryPlacePiece(Piece p, List<Placement> placed)
        {
            var orientations = p.GetOrientations();

            for (int tries = 0; tries < 200; tries++)
            {
                var (dx, dy, dz, name) = orientations[rng.Next(orientations.Count)];
                int x = rng.Next(5);
                int y = rng.Next(5);
                int z = rng.Next(5);

                if (CanFit(x, y, z, dx, dy, dz))
                {
                    Place(x, y, z, dx, dy, dz);
                    placed.Add(new Placement(p.Type, x, y, z, name));
                    return true;
                }
            }
            return false;
        }

        static bool CanFit(int x, int y, int z, int dx, int dy, int dz)
        {
            if (x + dx > 5 || y + dy > 5 || z + dz > 5)
                return false;

            for (int i = 0; i < dx; i++)
                for (int j = 0; j < dy; j++)
                    for (int k = 0; k < dz; k++)
                        if (cube[x + i, y + j, z + k] != 0)
                            return false;

            return true;
        }

        static void Place(int x, int y, int z, int dx, int dy, int dz)
        {
            for (int i = 0; i < dx; i++)
                for (int j = 0; j < dy; j++)
                    for (int k = 0; k < dz; k++)
                        cube[x + i, y + j, z + k] = 1;
        }

        static void ClearCube()
        {
            Array.Clear(cube, 0, cube.Length);
        }
    }

    class Piece
    {
        public string Type;
        public int Dx, Dy, Dz;

        public Piece(string type, int dx, int dy, int dz)
        {
            Type = type; Dx = dx; Dy = dy; Dz = dz;
        }

        public static Piece Create(string type)
        {
            return type switch
            {
                "Large" => new Piece("Large", 2, 2, 3),
                "Medium" => new Piece("Medium", 1, 2, 4),
                "Small" => new Piece("Small", 1, 1, 1),
                _ => throw new ArgumentException("Unknown type")
            };
        }

        public List<(int dx, int dy, int dz, string name)> GetOrientations()
        {
            var list = new List<(int, int, int, string)>();

            if (Type == "Small")
            {
                list.Add((1, 1, 1, "1x1x1"));
            }
            else if (Type == "Medium")
            {
                list.Add((1, 2, 4, "1x2x4"));
                list.Add((1, 4, 2, "1x4x2"));
                list.Add((2, 1, 4, "2x1x4"));
                list.Add((2, 4, 1, "2x4x1"));
                list.Add((4, 1, 2, "4x1x2"));
                list.Add((4, 2, 1, "4x2x1"));
            }
            else if (Type == "Large")
            {
                list.Add((2, 2, 3, "2x2x3"));
                list.Add((2, 3, 2, "2x3x2"));
                list.Add((3, 2, 2, "3x2x2"));
            }
            return list;
        }
    }

    class Placement
    {
        public string Type;
        public int X, Y, Z;
        public string Orientation;

        public Placement(string type, int x, int y, int z, string orientation)
        {
            Type = type; X = x; Y = y; Z = z; Orientation = orientation;
        }

        public override string ToString()
        {
            return $"{Type} @ ({X},{Y},{Z}) orientation={Orientation}";
        }
    }
}
