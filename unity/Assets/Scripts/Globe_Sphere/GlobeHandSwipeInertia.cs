using UnityEngine;

public class GlobeHandSwipeInertia : MonoBehaviour
{
    public Transform globeVisual;      // Your planet sphere
    public Transform leftHand;         // LeftHandAnchor
    public Transform rightHand;        // RightHandAnchor
    public float rotationSpeed = 100f; // How fast hand movement rotates globe
    public float inertiaDamping = 3f;  // How quickly inertia slows down
    public float maxVerticalAngle = 80f; // Clamp rotation X to prevent flipping

    private bool isDragging = false;
    private Transform activeHand;
    private Vector3 lastHandPos;

    private Vector2 angularVelocity; // x = vertical, y = horizontal

    void Update()
    {
        // Start dragging if hand is near globe
        if (!isDragging)
        {
            if (Vector3.Distance(leftHand.position, globeVisual.position) < 0.4f)
                StartDrag(leftHand);
            else if (Vector3.Distance(rightHand.position, globeVisual.position) < 0.4f)
                StartDrag(rightHand);
        }

        // Stop dragging if hand moves away
        if (isDragging && activeHand != null)
        {
            if (Vector3.Distance(activeHand.position, globeVisual.position) > 0.35f)
            {
                isDragging = false;
                activeHand = null;
            }
        }

        // Update rotation
        if (isDragging && activeHand != null)
        {
            Vector3 delta = activeHand.position - lastHandPos;

            angularVelocity.y = -delta.x * rotationSpeed; // horizontal
            angularVelocity.x = delta.y * rotationSpeed;  // vertical

            RotateGlobe(angularVelocity * Time.deltaTime);

            lastHandPos = activeHand.position;
        }
        else
        {
            // Apply inertia when hand released
            if (angularVelocity.magnitude > 0.01f)
            {
                RotateGlobe(angularVelocity * Time.deltaTime);

                // Slow down inertia over time
                angularVelocity = Vector2.Lerp(angularVelocity, Vector2.zero, Time.deltaTime * inertiaDamping);
            }
        }
    }

    void StartDrag(Transform hand)
    {
        isDragging = true;
        activeHand = hand;
        lastHandPos = hand.position;
    }

    void RotateGlobe(Vector2 rotation)
    {
        // Get current rotation
        Vector3 euler = globeVisual.eulerAngles;

        // Convert X rotation to -180..180 for clamping
        float x = euler.x;
        if (x > 180) x -= 360;

        x += rotation.x;

        // Clamp vertical rotation
        x = Mathf.Clamp(x, -maxVerticalAngle, maxVerticalAngle);

        // Apply rotation
        globeVisual.rotation = Quaternion.Euler(x, euler.y + rotation.y, 0);
    }
}