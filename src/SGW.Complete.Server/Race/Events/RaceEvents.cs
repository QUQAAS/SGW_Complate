using System.Text.Json.Serialization;

namespace SGW.Complete.Server.Race.Events;

public static class RaceEventNames
{
    public const string RequestRaceInvite = "SGW:Race:RequestInvite";
    public const string RespondInvite = "SGW:Race:RespondInvite";
    public const string CancelRace = "SGW:Race:Cancel";
    public const string RequestRaceTypes = "SGW:Race:RequestTypes";

    public const string InviteReceived = "SGW:Race:InviteReceived";
    public const string InviteResponse = "SGW:Race:InviteResponse";
    public const string RaceStarting = "SGW:Race:Starting";
    public const string Countdown = "SGW:Race:Countdown";
    public const string RaceStarted = "SGW:Race:Started";
    public const string RaceUpdate = "SGW:Race:Update";
    public const string RaceFinished = "SGW:Race:Finished";
    public const string RaceCancelled = "SGW:Race:Cancelled";
    public const string RaceTypesList = "SGW:Race:TypesList";
    public const string Error = "SGW:Race:Error";
}

public record RaceTypeInfo(string Id, string Name, string Description, List<float> DefaultDistances);

public record RaceInviteRequest(string RaceTypeId, float DistanceMeters, List<int> TargetCarIds);

public record RaceInviteEvent(int InviterCarId, string InviterName, string RaceTypeId, string RaceTypeName, float DistanceMeters, int InviteId);

public record InviteResponseEvent(int InviteId, bool Accepted);

public record GridPosition(int CarId, System.Numerics.Vector3 Position, System.Numerics.Quaternion Rotation);

public record RaceStartEvent(int InviteId, List<GridPosition> GridPositions, System.Numerics.Vector3 FinishLinePos, System.Numerics.Vector3 FinishLineDir, float DistanceMeters);

public record CountdownEvent(int Seconds);

public record RacerInfo(int CarId, string DriverName, float DistanceTraveled, float Speed, int Position, float? Points = null, int? Combo = null);

public record RaceUpdateEvent(float ElapsedTime, List<RacerInfo> Racers, float? FinishLineDistance = null);

public record FinalResult(int CarId, string DriverName, float Score, int Position);

public record RaceFinishEvent(int WinnerCarId, string WinnerName, List<FinalResult> Results);

public record RaceCancelEvent(string Reason);