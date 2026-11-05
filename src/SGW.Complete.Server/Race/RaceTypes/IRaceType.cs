using System.Numerics;

namespace SGW.Complete.Server.Race.RaceTypes;

public interface IRaceType
{
    string Id { get; }
    string Name { get; }
    string Description { get; }
    List<float> DefaultDistances { get; }

    void OnRaceStart(RaceSession session);
    void OnRaceUpdate(RaceSession session, float deltaTime);
    void OnCarPassedFinishLine(RaceSession session, int carId);
    void OnCarCrashed(RaceSession session, int carId);
    RaceFinishResult? CheckFinishCondition(RaceSession session);
}

public class RaceFinishResult
{
    public int WinnerCarId { get; set; }
    public List<FinalResult> Results { get; set; } = new();
    public string FinishReason { get; set; } = "";
}

public class FinalResult
{
    public int CarId { get; set; }
    public string DriverName { get; set; } = "";
    public float Score { get; set; }
    public int Position { get; set; }
}

public class RaceSession
{
    public int InviteId { get; set; }
    public string RaceTypeId { get; set; } = "";
    public float DistanceMeters { get; set; }
    public List<int> ParticipantCarIds { get; set; } = new();
    public Dictionary<int, RacerState> Racers { get; set; } = new();
    public Vector3 StartPos { get; set; }
    public Quaternion StartRot { get; set; }
    public Vector3 FinishLinePos { get; set; }
    public Vector3 FinishLineDir { get; set; }
    public RaceState State { get; set; } = RaceState.Waiting;
    public float ElapsedTime { get; set; }
    public DateTime StartTime { get; set; }
}

public class RacerState
{
    public int CarId { get; set; }
    public string DriverName { get; set; } = "";
    public float DistanceTraveled { get; set; }
    public float LastSpeed { get; set; }
    public float Points { get; set; }
    public int Combo { get; set; }
    public int MaxCombo { get; set; } = 3;
    public bool HasCrashed { get; set; }
    public bool Finished { get; set; }
    public float FinishTime { get; set; }
    public Vector3 LastPos { get; set; }
}

public enum RaceState { Waiting, Countdown, Racing, Finished, Cancelled }