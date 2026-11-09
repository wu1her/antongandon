using System;

namespace Lab4
{
    public class Privilege : Tax
    {
        protected bool hasPrivilege;
        protected double taxVip;

        public Privilege() : base()
        {
            hasPrivilege = random.Next(0, 2) == 1;
            taxVip = 0;
        }

        public void CalculateTaxVip(int t)
        {
            base.CalculateTax(t);
            if (hasPrivilege)
                taxVip = tax / 2;
            else
                taxVip = tax;
        }

        public override void Print()
        {
            base.Print();
            Console.WriteLine("Льгота: " + hasPrivilege);
            Console.WriteLine("Налог с учётом льготы: " + taxVip.ToString("F2"));
        }
    }
}
