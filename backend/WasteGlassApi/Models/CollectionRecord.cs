namespace WasteGlassApi.Models
{
    public class CollectionRecord
    {
        public int Id { get; set; }
        public int SupplierId { get; set; }
        public Supplier Supplier { get; set; } = null!;
        public double ClearKg { get; set; }
        public double ColouredKg { get; set; }
        public string Condition { get; set; } = string.Empty;
        public string Status { get; set; } = "Pending";
        public DateTime CollectedAt { get; set; } = DateTime.UtcNow;
        public string TripDate { get; set; } = DateTime.UtcNow.ToString("yyyy-MM-dd");
    }
}