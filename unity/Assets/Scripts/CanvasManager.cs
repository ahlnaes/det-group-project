using UnityEngine;

public class CanvasManager : MonoBehaviour
{
    [Header("Canvas References")]
    public GameObject canvasToHide;
    public GameObject canvasToShow;

    /// <summary>
    /// Hides the first canvas and shows the second one.
    /// </summary>
    public void SwapCanvases()
    {
        if (canvasToHide != null)
        {
            canvasToHide.SetActive(false);
        }

        if (canvasToShow != null)
        {
            canvasToShow.SetActive(true);
        }
    }

    /// <summary>
    /// Simply hides a specific canvas (useful for "Close" buttons).
    /// </summary>
    public void HideCanvas(GameObject targetCanvas)
    {
        if (targetCanvas != null)
        {
            targetCanvas.SetActive(false);
        }
    }
}