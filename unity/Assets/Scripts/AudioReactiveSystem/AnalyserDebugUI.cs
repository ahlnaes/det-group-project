using UnityEngine;

/// <summary>
/// Draws a simple spectrum analyser and RMS meter on screen using OnGUI.
/// No dependencies — for debug purposes only.
/// </summary>
public class AnalyserDebugUI : MonoBehaviour
{
    private AudioAnalyser _analyser;

    // Layout constants
    private const int BarWidth    = 60;
    private const int BarMaxHeight = 300;
    private const int BarY        = 400;
    private const int PaddingX    = 20;
    private const int RMSBarWidth = 20;

    private void Awake()
    {
        _analyser = GetComponent<AudioAnalyser>();
    }

    private void OnGUI()
    {
        if (_analyser == null) return;

        float[] bands = _analyser.Bands;
        float   rms   = _analyser.RMS;

        // Label
        GUI.Label(new Rect(10, 10, 300, 30), $"RMS: {rms:F4}");

        // Draw each frequency band as a vertical bar
        for (var i = 0; i < bands.Length; i++)
        {
            // Scale magnitude for visibility — raw values are very small
            float normalised = Mathf.Clamp01(bands[i] * 200f);
            int   barHeight  = Mathf.RoundToInt(normalised * BarMaxHeight);
            int   x          = PaddingX + i * (BarWidth + 10);

            // Background
            GUI.color = new Color(0.2f, 0.2f, 0.2f);
            GUI.DrawTexture(new Rect(x, BarY - BarMaxHeight, BarWidth, BarMaxHeight), Texture2D.whiteTexture);

            // Bar — colour shifts from blue (bass) to red (treble)
            float hue = (float)i / bands.Length * 0.66f;  // 0 = red, 0.66 = blue, reversed
            GUI.color = Color.HSVToRGB(0.66f - hue, 0.8f, 1f);
            GUI.DrawTexture(new Rect(x, BarY - barHeight, BarWidth, barHeight), Texture2D.whiteTexture);

            // Band label
            GUI.color = Color.white;
            GUI.Label(new Rect(x, BarY + 5, BarWidth, 20), $"B{i}");
        }

        // RMS bar on the right
        float rmsNormalised = Mathf.Clamp01(rms * 5f);
        int   rmsHeight     = Mathf.RoundToInt(rmsNormalised * BarMaxHeight);
        int   rmsX          = PaddingX + bands.Length * (BarWidth + 10) + 20;

        GUI.color = new Color(0.2f, 0.2f, 0.2f);
        GUI.DrawTexture(new Rect(rmsX, BarY - BarMaxHeight, RMSBarWidth, BarMaxHeight), Texture2D.whiteTexture);

        GUI.color = Color.green;
        GUI.DrawTexture(new Rect(rmsX, BarY - rmsHeight, RMSBarWidth, rmsHeight), Texture2D.whiteTexture);

        GUI.color = Color.white;
        GUI.Label(new Rect(rmsX, BarY + 5, 40, 20), "RMS");

        // Reset GUI color
        GUI.color = Color.white;
    }
}