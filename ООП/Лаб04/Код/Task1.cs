using System;

namespace Lab4
{
    public class Task1
    {
        public void Run()
        {
            int t = DateTime.Now.Year;
            House[] houses = new House[5];
            houses[0] = new House();
            houses[1] = new House();
            houses[2] = new DistrictHouse();
            houses[3] = new DistrictHouse();
            houses[4] = new DistrictHouse();

            for (int i = 0; i < houses.Length; i++)
            {
                Console.WriteLine("Дом № " + (i + 1));
                houses[i].Show();
                Console.WriteLine("Q = " + houses[i].Q(t).ToString("F4"));
                Console.WriteLine();
            }
        }
    }
}
