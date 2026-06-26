using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Models;

namespace WasteGlassApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Supplier> Suppliers { get; set; }
        public DbSet<CollectionRecord> CollectionRecords { get; set; }
    }
}