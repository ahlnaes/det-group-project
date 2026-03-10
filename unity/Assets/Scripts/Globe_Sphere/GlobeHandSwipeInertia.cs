using UnityEngine;

public class GlobeHandSwipeInertia : MonoBehaviour
{
    public Transform globeVisual;      
    public Transform leftHand;         
    public Transform rightHand;        
    public float rotationSpeed = 200f; 
    public float inertiaDamping = 3f;  

    private Transform activeHand = null;
    private Vector3 lastHandPos;
    private float angularVelocity;

    public WebSocketClientExample websocketController;

    // Hand radius for vibration
    public float vibrateRadius = 0.1f;

    // Track if vibration was already sent
    private bool handWasInside = false;

    void Update()
{
    Transform handToUse = null;

    if (Vector3.Distance(leftHand.position, globeVisual.position) < vibrateRadius)
        handToUse = leftHand;
    else if (Vector3.Distance(rightHand.position, globeVisual.position) < vibrateRadius)
        handToUse = rightHand;

    bool handInside = handToUse != null;

    // Hand ENTERS radius
    if (handInside && !handWasInside)
    {
        handWasInside = true;

        if (websocketController != null)
        {
            websocketController.SendVibrateOn();
            Debug.Log("Sent VibrateOn");
        }
    }

    // Hand LEAVES radius
    if (!handInside && handWasInside)
    {
        handWasInside = false;

        if (websocketController != null)
        {
            websocketController.SendVibrateOff();
            Debug.Log("Sent VibrateOff");
        }
    }

        // Handle rotation
        if (handToUse != null)
        {
            if (activeHand != handToUse)
            {
                activeHand = handToUse;
                lastHandPos = handToUse.position;
            }

            float deltaX = handToUse.position.x - lastHandPos.x;
            angularVelocity = -deltaX * rotationSpeed * 100f * Time.deltaTime;
            globeVisual.Rotate(Vector3.up, angularVelocity, Space.World);

            lastHandPos = handToUse.position;
        }
        else
        {
            activeHand = null;
            if (Mathf.Abs(angularVelocity) > 0.01f)
            {
                globeVisual.Rotate(Vector3.up, angularVelocity, Space.World);
                angularVelocity = Mathf.Lerp(angularVelocity, 0f, Time.deltaTime * inertiaDamping);
            }
        }
    }
}