using UnityEngine;

public class ButtonManager : MonoBehaviour
{
    public GameObject[] objects; // Drag Object1–Object6 here in Inspector

    public void ShowObject(int index)
    {
        if (index >= 0 && index < objects.Length)
        {
            objects[index].SetActive(true);
        }
    }
}