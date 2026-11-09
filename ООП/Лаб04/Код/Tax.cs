using System;

namespace Lab4
{
    public class Tax
    {
        protected static Random random = new Random();
        protected int code;
        protected int birthYear;
        protected double income;
        protected double tax;

        public Tax()
        {
            code = random.Next(1000, 10000);
            birthYear = random.Next(DateTime.Now.Year - 80,
                                    DateTime.Now.Year - 9);
            income = random.Next(0, 20001);
            tax = 0;
        }

        public virtual void Print()
        {
            Console.WriteLine("Код: " + code);
            Console.WriteLine("Год рождения: " + birthYear);
            Console.WriteLine("Доход: " + income.ToString("F2"));
            Console.WriteLine("Налог: " + tax.ToString("F2"));
        }

        public void CalculateTax(int t)
        {
            int age = t - birthYear;
            if (age < 17 || income < 1000)
                tax = 0;
            else if (income <= 10000)
                tax = income * 0.2;
            else
                tax = income * 0.25;
        }
    }
}
