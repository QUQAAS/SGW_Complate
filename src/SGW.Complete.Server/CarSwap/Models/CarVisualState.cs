namespace SGW.Complete.Server.CarSwap.Models;

public class CarVisualState
{
    public int PlayerCarId { get; set; }
    public string OriginalModel { get; set; } = "";
    public string OriginalSkin { get; set; } = "";
    public string VisualModel { get; set; } = "";
    public string VisualSkin { get; set; } = "";
    public int EntryIndex { get; set; } = -1;
    public WheelFitData WheelFitData { get; set; } = new();
    public bool IsSwapped { get; set; }
    public DateTime SwapTime { get; set; }
}

public class WheelFitData
{
    public float FrontOffsetX { get; set; }
    public float RearOffsetX { get; set; }
    public float HeightOffset { get; set; }
    public float Scale { get; set; } = 1.0f;
    public float CamberFront { get; set; }
    public float CamberRear { get; set; }
}