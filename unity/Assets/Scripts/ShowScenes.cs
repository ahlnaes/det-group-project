using UnityEngine;

public class ShowScenes : MonoBehaviour
{
    // Drag these in the Inspector
    public GameObject Cylinder;
    public GameObject newCylinder_environment;

    // Call this function from the Button's OnClick
    public void OnButtonClicked()
    {
        if (Cylinder != null)
            Cylinder.SetActive(true);  // Unhide Cylinder

        if (newCylinder_environment != null)
            newCylinder_environment.SetActive(false);  // Hide environment
    }
}