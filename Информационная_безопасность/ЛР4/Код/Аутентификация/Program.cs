using System;
using System.Text;

class Program
{
    static char NextLetter(char c)
    {
        if (c == 'z') return 'a';
        return (char)(c + 1);
    }

    static char PrevLetter(char c)
    {
        if (c == 'a') return 'z';
        return (char)(c - 1);
    }

    static string ReadPassword()
    {
        string password = "";
        while (true)
        {
            ConsoleKeyInfo key = Console.ReadKey(true);
            if (key.Key == ConsoleKey.Enter)
            {
                Console.WriteLine();
                return password;
            }
            if (key.Key == ConsoleKey.Backspace)
            {
                if (password.Length > 0)
                {
                    password = password.Remove(password.Length - 1);
                    Console.Write("\b \b");
                }
            }
            else if (!char.IsControl(key.KeyChar))
            {
                password += key.KeyChar;
                Console.Write("*");
            }
        }
    }

    static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        string word1 = "dog";
        string word2 = "zaps";
        string word3 = "budge";

        char c1 = NextLetter(word2[0]);
        char c2 = PrevLetter(word2[word2.Length - 2]);
        char c3;
        if (word3.Length % 2 != 0)
        {
            char middle = word3[word3.Length / 2];
            c3 = NextLetter(PrevLetter(middle));
        }
        else
        {
            c3 = PrevLetter(word3[word3.Length / 2 - 1]);
        }

        int position = (word1.Length + word2.Length) % 26;
        if (position == 0) position = 26;
        char c4 = (char)('a' + position - 1);
        string correctPassword = "" + c1 + c2 + c3 + c4;

        Console.WriteLine("Вариант 8: " + word1 + ", " + word2 + ", " + word3);
        Console.WriteLine("Сгенерированный пароль: " + correctPassword);
        Console.Write("Введите пароль: ");
        string input = ReadPassword();
        if (input == correctPassword)
            Console.WriteLine("Результат: пароль верен");
        else
            Console.WriteLine("Результат: пароль неверен");
    }
}
