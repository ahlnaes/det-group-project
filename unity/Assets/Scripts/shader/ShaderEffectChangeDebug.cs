using UnityEngine;
using UnityEngine.InputSystem;

public class ShaderEffectInput : MonoBehaviour
{
    [SerializeField] private ShaderEffectController controller;

    void Update()
    {
        if (Keyboard.current.rightArrowKey.wasPressedThisFrame) controller.NextEffect();
        if (Keyboard.current.leftArrowKey.wasPressedThisFrame)  controller.PreviousEffect();
    }
}