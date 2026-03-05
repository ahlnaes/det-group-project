using UnityEngine;

public class GlobeHandSwipe : MonoBehaviour
{
    public Transform globeVisual;      // Your planet sphere
    public Transform leftHand;         // LeftHandAnchor
    public Transform rightHand;        // RightHandAnchor
    public float rotationSpeed = 100f; // Adjust sensitivity

    private bool isDragging = false;
    private Transform activeHand;
    private Vector3 lastHandPos;

    void Update()
    {
        // Start dragging if hand is near globe
        if (!isDragging)
        {
            if (Vector3.Distance(leftHand.position, globeVisual.position) < 0.3f)
            {
                StartDrag(leftHand);
            }
            else if (Vector3.Distance(rightHand.position, globeVisual.position) < 0.3f)
            {
                StartDrag(rightHand);
            }
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

        // Rotate globe while dragging
        if (isDragging && activeHand != null)
        {
            Vector3 delta = activeHand.position - lastHandPos;

            // Horizontal movement → rotate around Y
            globeVisual.Rotate(Vector3.up, -delta.x * rotationSpeed * Time.deltaTime, Space.World);

            // Vertical movement → rotate around X
            globeVisual.Rotate(Vector3.right, delta.y * rotationSpeed * Time.deltaTime, Space.World);

            lastHandPos = activeHand.position;
        }
    }

    void StartDrag(Transform hand)
    {
        isDragging = true;
        activeHand = hand;
        lastHandPos = hand.position;
    }
}