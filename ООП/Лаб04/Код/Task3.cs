using System;

namespace Lab4
{
    public class Task3
    {
        public void Run()
        {
            int t = DateTime.Now.Year;
            Tax person;

            for (int i = 0; i < 5; i++)
            {
                if (i < 2)
                    person = new Tax();
                else
                    person = new Privilege();

                Console.WriteLine("Налогоплательщик № " + (i + 1));
                person.CalculateTax(t);
                if (person is Privilege)
                {
                    Privilege vip = (Privilege)person;
                    vip.CalculateTaxVip(t);
                }
                person.Print();
                Console.WriteLine();
            }
        }
    }
}
