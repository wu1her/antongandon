using System;
using System.Text;
using System.Security.Cryptography;

class Program
{
    static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        double P = 1e-7;
        int V = 15;
        int T = 20 * 24 * 60;
        double Smin = Math.Ceiling(V * T / P);

        string alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        int A = alphabet.Length;
        int L = 1;
        while (Math.Pow(A, L) < Smin)
        {
            L++;
        }

        double S = Math.Pow(A, L);
        double minutes = S / V;
        double years = minutes / (60 * 24 * 365);

        Console.WriteLine("Вариант 8. Генератор паролей");
        Console.WriteLine("P = " + P);
        Console.WriteLine("V = " + V + " паролей/мин");
        Console.WriteLine("T = " + T + " мин");
        Console.WriteLine("S* = " + Smin.ToString("F0"));
        Console.WriteLine("A = " + A + ", L = " + L);
        Console.WriteLine("S = " + S.ToString("F0"));
        Console.WriteLine("Время полного перебора: " + years.ToString("F2") + " лет");
        Console.WriteLine("Среднее время: " + (years / 2).ToString("F2") + " лет");
        Console.WriteLine("Пять примеров паролей:");

        for (int i = 1; i <= 5; i++)
        {
            string password = "";
            for (int j = 0; j < L; j++)
            {
                int index = RandomNumberGenerator.GetInt32(A);
                password += alphabet[index];
            }
            Console.WriteLine(i + ") " + password);
        }
    }
}
