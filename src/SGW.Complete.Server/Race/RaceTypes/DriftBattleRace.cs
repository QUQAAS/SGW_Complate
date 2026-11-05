using System.Collections.Generic;
using System.Linq;

namespace SGW.Complete.Server.Race.RaceTypes;

public class DriftBattleRace : IRaceType
{
    public string Id => "drift_battle";
    public string Name => "Drift Kapışması";
    public string Description => "Hız yönü ile araç yönü arası açı (slip angle) puan kazandırır";
    public List<float> DefaultDistances => new() { 3000, 5000, 10000, 20000 };

    private const float MIN_DRIFT_ANGLE_DEG = 15f;
    private const float MAX_DRIFT_ANGLE_DEG = 60f;
    private const float MIN_SPEED_KMH = 40f;
    private const int MAX_COMBO = 3;

    public void OnRaceStart(RaceSession session) { }

    public void OnRaceUpdate(RaceSession session, float deltaTime)
    {
        foreach (var racer in session.Racers.Values)
        {
            if (racer.Finished || racer.HasCrashed) continue;

            // Drift açısı hesapla (sunucuda car.Velocity ve car.Rotation varsa)
            // float driftAngle = CalculateDriftAngle(racer);
            // if (driftAngle >= MIN_DRIFT_ANGLE_DEG) AwardDriftPoints(racer, driftAngle);
            // else racer.Combo = 0;

            racer.DistanceTraveled += racer.LastSpeed * (deltaTime / 3.6f);
        }
    }

    private void AwardDriftPoints(RacerState racer, float angle)
    {
        racer.Combo = Math.Min(racer.Combo + 1, MAX_COMBO);
        float multiplier = 1 + (racer.Combo - 1) * 0.5f;
        racer.Points += angle * 10 * multiplier;
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