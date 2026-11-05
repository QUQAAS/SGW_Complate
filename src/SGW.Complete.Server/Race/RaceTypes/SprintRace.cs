using System.Collections.Generic;
using System.Linq;

namespace SGW.Complete.Server.Race.RaceTypes;

public class SprintRace : IRaceType
{
    public string Id => "sprint";
    public string Name => "Sprint Yarışı";
    public string Description => "Kısa mesafe, ilk bitiren kazanır";
    public List<float> DefaultDistances => new() { 400, 800, 1000, 2000 };

    public void OnRaceStart(RaceSession session) { }

    public void OnRaceUpdate(RaceSession session, float deltaTime) { }

    public void OnCarPassedFinishLine(RaceSession session, int carId)
    {
        if (session.Racers.TryGetValue(carId, out var racer) && !racer.Finished)
        {
            racer.Finished = true;
            racer.FinishTime = session.ElapsedTime;
        }
    }

    public void OnCarCrashed(RaceSession session, int carId)
    {
        if (session.Racers.TryGetValue(carId, out var racer))
            racer.HasCrashed = true;
    }

    public RaceFinishResult? CheckFinishCondition(RaceSession session)
    {
        var finished = session.Racers.Values
            .Where(r => r.Finished)
            .OrderBy(r => r.FinishTime)
            .ToList();

        if (finished.Count > 0)
        {
            return new RaceFinishResult
            {
                WinnerCarId = finished[0].CarId,
                Results = finished.Select((r, i) => new FinalResult
                {
                    CarId = r.CarId,
                    DriverName = r.DriverName,
                    Score = r.FinishTime,
                    Position = i + 1
                }).ToList(),
                FinishReason = "Finish line crossed"
            };
        }

        var active = session.Racers.Values.Where(r => !r.HasCrashed).ToList();
        if (active.Count == 0) return new RaceFinishResult { FinishReason = "All crashed" };

        return null;
    }
}