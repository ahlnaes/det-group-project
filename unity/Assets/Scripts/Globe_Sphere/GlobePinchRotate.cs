using UnityEngine;

public class GlobePinchRotate : MonoBehaviour
{
    public Transform globeVisual;

    public Transform leftIndexTip;   // b_l_index2
    public Transform leftThumbTip;   // b_l_thumb2

    public Transform rightIndexTip;  // b_r_index2
    public Transform rightThumbTip;  // b_r_thumb2

    public float rotationSpeed = 100f;

    private bool isDragging = false;
    private Transform activeHandIndex;
    private Transform activeHandThumb;
    private Vector3 lastHandPos;

    void Update()
    {
        // Check for pinch on left hand
        if (!isDragging && Vector3.Distance(leftIndexTip.position, leftThumbTip.position) < 0.03f)
        {
            StartDrag(leftIndexTip, leftThumbTip);
        }
        // Check for pinch on right hand
        else if (!isDragging && Vector3.Distance(rightIndexTip.position, rightThumbTip.position) < 0.03f)
        {
            StartDrag(rightIndexTip, rightThumbTip);
        }

        // Stop dragging if pinch released
        if (isDragging)
        {
            if (Vector3.Distance(activeHandIndex.position, activeHandThumb.position) > 0.04f)
            {
                isDragging = false;
            }
        }

        // Rotate globe while dragging
        if (isDragging)
        {
            Vector3 delta = activeHandIndex.position - lastHandPos;
            globeVisual.Rotate(Vector3.up, -delta.x * rotationSpeed * Time.deltaTime, Space.World);
            globeVisual.Rotate(Vector3.right, delta.y * rotationSpeed * Time.deltaTime, Space.World);

            lastHandPos = activeHandIndex.position;
        }
    }

    void StartDrag(Transform index, Transform thumb)
    {
        isDragging = true;
        activeHandIndex = index;
        activeHandThumb = thumb;
        lastHandPos = index.position;
    }
}