using UnityEngine;
using System.Collections;

public class CanvasManager : MonoBehaviour
{
    [Header("Canvas References")]
    public GameObject canvasToHide;
    public GameObject canvasToShow;

    [Header("Delay Settings")]
    public float delayTime = 3f; // Default delay of 3 seconds

    /// <summary>
    /// Starts the delayed canvas swap.
    /// </summary>
    public void SwapCanvases()
    {
        StartCoroutine(SwapWithDelay());
    }

    private IEnumerator SwapWithDelay()
    {
        // Disable both canvases
        if (canvasToHide != null)
        {
            canvasToHide.SetActive(false);
        }

        if (canvasToShow != null)
        {
            canvasToShow.SetActive(false);
        }

        // Wait for delay
        yield return new WaitForSeconds(delayTime);

        // Enable the exit canvas
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