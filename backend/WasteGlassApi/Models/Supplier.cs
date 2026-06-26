namespace WasteGlassApi.Models
{
    public class Supplier
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string BarcodeId { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double ExpectedClearKg { get; set; }
        public double ExpectedColouredKg { get; set; }
        public string Address { get; set; } = string.Empty;
        public ICollection<CollectionRecord> CollectionRecords { get; set; } = new List<CollectionRecord>();
    }
}