using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Data;
using WasteGlassApi.Models;

namespace WasteGlassApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SuppliersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SuppliersController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/suppliers/today
        [HttpGet("today")]
        public async Task<IActionResult> GetTodaySuppliers()
        {
            var today = DateTime.UtcNow.ToString("yyyy-MM-dd");
            var suppliers = await _context.Suppliers.ToListAsync();

            var collectedIds = await _context.CollectionRecords
                .Where(c => c.TripDate == today)
                .Select(c => c.SupplierId)
                .ToListAsync();

            var supplierDtos = suppliers.Select(s => new
            {
                s.Id,
                s.Name,
                s.BarcodeId,
                s.Latitude,
                s.Longitude,
                s.Address,
                s.ExpectedClearKg,
                s.ExpectedColouredKg,
                Status = collectedIds.Contains(s.Id) ? "Collected" : "Pending"
            }).ToList();

            return Ok(supplierDtos);
        }

        // GET: api/suppliers/route
        [HttpGet("route")]
        public async Task<IActionResult> GetOptimalRoute()
        {
            var today = DateTime.UtcNow.ToString("yyyy-MM-dd");
            var suppliers = await _context.Suppliers.ToListAsync();

            var collectedIds = await _context.CollectionRecords
                .Where(c => c.TripDate == today)
                .Select(c => c.SupplierId)
                .ToListAsync();

            // Collector starting location (Colombo, Sri Lanka)
            double startLat = 6.9271;
            double startLon = 79.8612;

            var sorted = GetDijkstraRoute(suppliers, startLat, startLon);

            var result = sorted.Select((s, index) => new
            {
                s.Id,
                s.Name,
                s.BarcodeId,
                s.Latitude,
                s.Longitude,
                s.Address,
                s.ExpectedClearKg,
                s.ExpectedColouredKg,
                Status = collectedIds.Contains(s.Id) ? "Collected" :
                         (index == collectedIds.Count ? "Next" : "Pending"),
                StopOrder = index + 1
            });

            var totalDistance = CalculateTotalDistance(sorted, startLat, startLon);

            return Ok(new { route = result, totalDistanceKm = Math.Round(totalDistance, 2) });
        }

        // POST: api/suppliers/collect
        [HttpPost("collect")]
        public async Task<IActionResult> SubmitCollection([FromBody] CollectionSubmitDto dto)
        {
            var supplier = await _context.Suppliers
                .FirstOrDefaultAsync(s => s.BarcodeId == dto.BarcodeId);

            if (supplier == null)
                return NotFound(new { message = "Supplier not found for this barcode" });

            var today = DateTime.UtcNow.ToString("yyyy-MM-dd");

            var existing = await _context.CollectionRecords
                .FirstOrDefaultAsync(c => c.SupplierId == supplier.Id && c.TripDate == today);

            if (existing != null)
                return BadRequest(new { message = "Already collected for this supplier today" });

            var record = new CollectionRecord
            {
                SupplierId = supplier.Id,
                ClearKg = dto.ClearKg,
                ColouredKg = dto.ColouredKg,
                Condition = dto.Condition,
                Status = "Collected",
                TripDate = today,
                CollectedAt = DateTime.UtcNow
            };

            _context.CollectionRecords.Add(record);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Collection recorded", supplierId = supplier.Id });
        }

        // GET: api/suppliers/trip-summary
        [HttpGet("trip-summary")]
        public async Task<IActionResult> GetTripSummary()
        {
            var today = DateTime.UtcNow.ToString("yyyy-MM-dd");

            var records = await _context.CollectionRecords
                .Include(c => c.Supplier)
                .Where(c => c.TripDate == today)
                .ToListAsync();

            var summary = records.Select(r => new
            {
                r.Supplier.Name,
                r.Supplier.BarcodeId,
                r.ClearKg,
                r.ColouredKg,
                r.Condition,
                r.CollectedAt,
                TotalKg = r.ClearKg + r.ColouredKg,
                Shortfall = (r.ClearKg < r.Supplier.ExpectedClearKg ||
                            r.ColouredKg < r.Supplier.ExpectedColouredKg),
                ExpectedClearKg = r.Supplier.ExpectedClearKg,
                ExpectedColouredKg = r.Supplier.ExpectedColouredKg
            });

            return Ok(new
            {
                collections = summary,
                totalClearKg = records.Sum(r => r.ClearKg),
                totalColouredKg = records.Sum(r => r.ColouredKg),
                totalKg = records.Sum(r => r.ClearKg + r.ColouredKg),
                totalStops = records.Count
            });
        }

        // Haversine formula
        private double Haversine(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371;
            var dLat = ToRad(lat2 - lat1);
            var dLon = ToRad(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private double ToRad(double deg) => deg * Math.PI / 180;

        // Dijkstra/Greedy nearest neighbour route
        private List<Supplier> GetDijkstraRoute(List<Supplier> suppliers, double startLat, double startLon)
        {
            var remaining = new List<Supplier>(suppliers);
            var route = new List<Supplier>();
            double currentLat = startLat;
            double currentLon = startLon;

            while (remaining.Count > 0)
            {
                var nearest = remaining
                    .OrderBy(s => Haversine(currentLat, currentLon, s.Latitude, s.Longitude))
                    .First();
                route.Add(nearest);
                currentLat = nearest.Latitude;
                currentLon = nearest.Longitude;
                remaining.Remove(nearest);
            }

            return route;
        }

        private double CalculateTotalDistance(List<Supplier> route, double startLat, double startLon)
        {
            double total = 0;
            double curLat = startLat, curLon = startLon;
            foreach (var s in route)
            {
                total += Haversine(curLat, curLon, s.Latitude, s.Longitude);
                curLat = s.Latitude;
                curLon = s.Longitude;
            }
            return total;
        }
    }

    public class CollectionSubmitDto
    {
        public string BarcodeId { get; set; } = string.Empty;
        public double ClearKg { get; set; }
        public double ColouredKg { get; set; }
        public string Condition { get; set; } = string.Empty;
    }
}