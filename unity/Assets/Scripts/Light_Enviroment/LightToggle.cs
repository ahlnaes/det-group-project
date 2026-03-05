using UnityEngine;

public class LightToggle : MonoBehaviour
{
    public Light targetLight;

    public void ToggleLight()
    {
        targetLight.enabled = !targetLight.enabled;
    }
}