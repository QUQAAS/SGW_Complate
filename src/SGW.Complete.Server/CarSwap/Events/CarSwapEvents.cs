using System.Text.Json.Serialization;

namespace SGW.Complete.Server.CarSwap.Events;

public static class CarSwapEventNames
{
    public const string RequestCarList = "SGW:CarSwap:RequestCarList";
    public const string RequestSwap = "SGW:CarSwap:RequestSwap";
    public const string RequestReset = "SGW:CarSwap:RequestReset";
    public const string RequestFineTuneSave = "SGW:CarSwap:RequestFineTuneSave";
    public const string RequestFineTuneLoad = "SGW:CarSwap:RequestFineTuneLoad";

    public const string CarListResponse = "SGW:CarSwap:CarListResponse";
    public const string SwapExecuted = "SGW:CarSwap:SwapExecuted";
    public const string SwapReset = "SGW:CarSwap:SwapReset";
    public const string PlayerVisualState = "SGW:CarSwap:PlayerVisualState";
    public const string FineTuneSaved = "SGW:CarSwap:FineTuneSaved";
    public const string FineTuneLoaded = "SGW:CarSwap:FineTuneLoaded";
    public const string Error = "SGW:CarSwap:Error";
}

public record CarInfo(
    string Model,
    string Skin,
    string DisplayName,
    bool IsCompatible,
    string CompatibilityReason,
    float FrontTrack,
    float RearTrack,
    float WheelRadius,
    float FrontWheelOffsetX,
    float RearWheelOffsetX
);

public record CarListResponseEvent(
    List<CarInfo> AvailableCars,
    string CurrentCarModel
);

public record SwapRequestEvent(
    int TargetCarIndex,
    string TargetModel,
    string TargetSkin
);

public record WheelFitData(
    float FrontOffsetX,
    float RearOffsetX,
    float HeightOffset,
    float Scale,
    float CamberFront,
    float CamberRear
);

public record SwapExecutedEvent(
    int PlayerCarId,
    string NewModel,
    string NewSkin,
    int NewEntryIndex,
    WheelFitData WheelFitData
);

public record PlayerVisualStateEvent(
    int PlayerCarId,
    string VisualModel,
    string VisualSkin,
    WheelFitData WheelFitData,
    bool IsSwapped
);

public record SwapResetEvent(int PlayerCarId);
public record FineTuneSavedEvent(string CacheKey, WheelFitData Data);
public record FineTuneLoadedEvent(string CacheKey, WheelFitData Data);
public record ErrorEvent(string Message);