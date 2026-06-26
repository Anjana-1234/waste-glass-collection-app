using WasteGlassApi.Models;

namespace WasteGlassApi.Data
{
    public static class DbSeeder
    {
        public static void Seed(AppDbContext context)
        {
            if (context.Suppliers.Any()) return;

            var suppliers = new List<Supplier>
            {
                new Supplier
                {
                    Name = "Colombo Glass Depot",
                    BarcodeId = "SUP001",
                    Latitude = 6.9271,
                    Longitude = 79.8612,
                    Address = "123 Main Street, Colombo 01",
                    ExpectedClearKg = 50,
                    ExpectedColouredKg = 30
                },
                new Supplier
                {
                    Name = "Nugegoda Recyclers",
                    BarcodeId = "SUP002",
                    Latitude = 6.8728,
                    Longitude = 79.8878,
                    Address = "45 High Level Road, Nugegoda",
                    ExpectedClearKg = 40,
                    ExpectedColouredKg = 20
                },
                new Supplier
                {
                    Name = "Dehiwala Glass Store",
                    BarcodeId = "SUP003",
                    Latitude = 6.8517,
                    Longitude = 79.8653,
                    Address = "78 Galle Road, Dehiwala",
                    ExpectedClearKg = 60,
                    ExpectedColouredKg = 25
                },
                new Supplier
                {
                    Name = "Maharagama Bottles",
                    BarcodeId = "SUP004",
                    Latitude = 6.8483,
                    Longitude = 79.9264,
                    Address = "12 High Street, Maharagama",
                    ExpectedClearKg = 35,
                    ExpectedColouredKg = 15
                },
                new Supplier
                {
                    Name = "Kotte Glass Hub",
                    BarcodeId = "SUP005",
                    Latitude = 6.8935,
                    Longitude = 79.9076,
                    Address = "56 Parliament Road, Kotte",
                    ExpectedClearKg = 45,
                    ExpectedColouredKg = 35
                }
            };

            context.Suppliers.AddRange(suppliers);
            context.SaveChanges();
        }
    }
}