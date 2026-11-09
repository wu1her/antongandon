using System;

namespace Lab4
{
    public class House
    {
        protected static Random random = new Random();
        protected int rooms;
        protected int year;

        public House()
        {
            rooms = random.Next(1, 7);
            year = random.Next(1940, DateTime.Now.Year);
        }

        public virtual void Show()
        {
            Console.WriteLine("Количество комнат: " + rooms);
            Console.WriteLine("Год постройки: " + year);
        }

        public virtual double Q(int t)
        {
            return rooms + 2.0 / (t - year);
        }
    }
}
