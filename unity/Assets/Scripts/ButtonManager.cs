using UnityEngine;

public class ButtonManager : MonoBehaviour
{
    public GameObject[] objects; // Objects to SHOW
    public GameObject[] buttons; // Buttons to HIDE (match the order of 'objects')

    public void ShowObjectAndHideButton(int index)
    {
        // 1. Show the object at this index
        if (index >= 0 && index < objects.Length)
        {
            objects[index].SetActive(true);
        }

        // 2. Hide the button at this same index
        if (index >= 0 && index < buttons.Length)
        {
            buttons[index].SetActive(false);
        }
    }
}