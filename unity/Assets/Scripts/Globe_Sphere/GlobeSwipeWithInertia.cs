using UnityEngine;

public class GlobeSwipeWithInertia : MonoBehaviour
{
    public Transform globeVisual;
    public float rotationSpeed = 5f;
    public float inertiaDamping = 3f;

    private Transform activeFinger;
    private Vector3 lastFingerPos;
    private float angularVelocity;
    private bool dragging = false;

    void Update()
    {
        if (dragging && activeFinger != null)
        {
            Vector3 delta = activeFinger.position - lastFingerPos;

            float horizontal = delta.x;

            angularVelocity = horizontal * rotationSpeed * 100f;

            globeVisual.Rotate(Vector3.up, -angularVelocity * Time.deltaTime);

            lastFingerPos = activeFinger.position;
        }
        else
        {
            // Inertia spin
            if (Mathf.Abs(angularVelocity) > 0.01f)
            {
                globeVisual.Rotate(Vector3.up, -angularVelocity * Time.deltaTime);
                angularVelocity = Mathf.Lerp(angularVelocity, 0, Time.deltaTime * inertiaDamping);
            }
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (IsFinger(other))
        {
            activeFinger = other.transform;
            dragging = true;
            lastFingerPos = activeFinger.position;
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.transform == activeFinger)
        {
            dragging = false;
            activeFinger = null;
        }
    }

    private bool IsFinger(Collider col)
    {
        return col.name.Contains("IndexTip");
    }
}