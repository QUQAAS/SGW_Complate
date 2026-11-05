using System.Collections.Generic;
using System.Linq;

namespace SGW.Complete.Server.Race.RaceTypes;

public class CannonballRace : IRaceType
{
    public string Id => "cannonball";
    public string Name => "Makas Yarışı";
    public string Description => "Yüksek hızda diğer araçlara yakın geçiş yaparak puan kazan";
    public List<float> DefaultDistances => new() { 5000, 10000, 20000, 50000 };

    private const float NEAR_MISS_DISTANCE = 15f;
    private const float MIN_SPEED_KMH = 100f;
    private const int MAX_COMBO = 3;

    public void OnRaceStart(RaceSession session) { }

    public void OnRaceUpdate(RaceSession session, float deltaTime)
    {
        foreach (var racer in session.Racers.Values)
        {
            if (racer.Finished || racer.HasCrashed) continue;

            if (racer.LastSpeed >= MIN_SPEED_KMH)
            {
                CheckNearMisses(session, racer);
            }

            racer.DistanceTraveled += racer.LastSpeed * (deltaTime / 3.6f);
        }
    }

    private void CheckNearMisses(RaceSession session, RacerState racer)
    {
        // Sunucuda car.Position varsa mesafe kontrolü yap
        // Bu basit implementasyon - gerçekte RaceManager pozisyonları günceller
    }

    private void AwardPoints(RacerState racer)
    {
        racer.Combo = Math.Min(racer.Combo + 1, MAX_COMBO);
        racer.Points += 100 * racer.Combo;
    }

    public void OnCarPassedFinishLine(RaceSession session, int carId) { }

    public void OnCarCrashed(RaceSession session, int carId)
    {
        if (session.Racers.TryGetValue(carId, out var racer))
        {
            racer.HasCrashed = true;
            racer.Points = 0;
            racer.Combo = 0;
        }
    }

    public RaceFinishResult? CheckFinishCondition(RaceSession session)
    {
        var finished = session.Racers.Values
            .Where(r => r.DistanceTraveled >= session.DistanceMeters || r.HasCrashed)
            .OrderByDescending(r => r.Points)
            .ToList();

        if (finished.Count == session.Racers.Count)
        {
            return new RaceFinishResult
            {
                WinnerCarId = finished[0].CarId,
                Results = finished.Select((r, i) => new FinalResult
                {
                    CarId = r.CarId,
                    DriverName = r.DriverName,
                    Score = r.Points,
                    Position = i + 1
                }).ToList(),
                FinishReason = "Distance completed"
            };
        }
        return null;
    }
}