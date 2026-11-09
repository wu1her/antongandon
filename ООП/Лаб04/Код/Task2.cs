using System;

namespace Lab4
{
    public class Task2
    {
        public void Run()
        {
            Parall[] figures = new Parall[5];
            figures[0] = new Parall();
            figures[1] = new Parall();
            figures[2] = new Kub();
            figures[3] = new Kub();
            figures[4] = new Kub();

            for (int i = 0; i < figures.Length; i++)
            {
                Console.WriteLine("Фигура № " + (i + 1));
                Console.WriteLine("Площадь: " + figures[i].Sqr());
                Console.WriteLine("Объём: " + figures[i].V());
                Console.WriteLine();
            }
        }
    }
}
