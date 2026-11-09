using System;

namespace Lab4
{
    public class DistrictHouse : House
    {
        protected string p;

        public DistrictHouse() : base()
        {
            if (random.Next(0, 2) == 0)
                p = "центральный";
            else
                p = "окраина";
        }

        public override void Show()
        {
            base.Show();
            Console.WriteLine("Район: " + p);
        }

        public override double Q(int t)
        {
            double q = base.Q(t);
            if (p == "центральный")
                return q * 2;
            else
                return q * 0.5;
        }
    }
}
