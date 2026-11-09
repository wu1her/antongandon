using System;

namespace Lab4
{
    public class Parall
    {
        protected static Random random = new Random();
        protected int a;
        protected int b;
        protected int c;

        public Parall()
        {
            a = random.Next(1, 11);
            b = random.Next(1, 11);
            c = random.Next(1, 11);
        }

        public virtual double Sqr()
        {
            return 2 * (a * b + a * c + b * c);
        }

        public virtual double V()
        {
            return a * b * c;
        }
    }
}
