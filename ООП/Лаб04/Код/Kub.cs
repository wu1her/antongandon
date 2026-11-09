namespace Lab4
{
    public class Kub : Parall
    {
        public Kub() : base()
        {
            b = a;
            c = a;
        }

        public override double Sqr()
        {
            return 6 * a * a;
        }

        public override double V()
        {
            return a * a * a;
        }
    }
}
