using UnityEngine;

public class GlobeOneFingerScroll : MonoBehaviour
{
    public Transform globeVisual;   // Your planet sphere
    public Transform leftFinger;    // e.g., b_l_index2
    public Transform rightFinger;   // e.g., b_r_index2
    public float rotationSpeed = 200f;

    private bool isDragging = false;
    private Transform activeFinger;
    private Vector3 lastFingerPos;

    void Update()
    {
        // Start dragging if finger is close to globe
        if (!isDragging)
        {
            if (Vector3.Distance(leftFinger.position, globeVisual.position) < 0.2f)
            {
                StartDrag(leftFinger);
            }
            else if (Vector3.Distance(rightFinger.position, globeVisual.position) < 0.2f)
            {
                StartDrag(rightFinger);
            }
        }

        // Stop dragging if finger moves away
        if (isDragging && activeFinger != null)
        {
            if (Vector3.Distance(activeFinger.position, globeVisual.position) > 0.25f)
            {
                isDragging = false;
                activeFinger = null;
            }
        }

        // Rotate globe while dragging
        if (isDragging && activeFinger != null)
        {
            Vector3 delta = activeFinger.position - lastFingerPos;

            // Horizontal drag rotates globe around Y axis
            globeVisual.Rotate(Vector3.up, -delta.x * rotationSpeed * Time.deltaTime, Space.World);

            // Vertical drag rotates globe around X axis
            globeVisual.Rotate(Vector3.right, delta.y * rotationSpeed * Time.deltaTime, Space.World);

            lastFingerPos = activeFinger.position;
        }
    }

    void StartDrag(Transform finger)
    {
        isDragging = true;
        activeFinger = finger;
        lastFingerPos = finger.position;
    }
}