using shader;
using UnityEngine;
using UnityEngine.InputSystem;

public class ShaderEffectInput : MonoBehaviour
{
    [SerializeField] private ShaderEffectManager controller;

    void Update()
    {
        if (Keyboard.current.rightArrowKey.wasPressedThisFrame) controller.Next();
        if (Keyboard.current.leftArrowKey.wasPressedThisFrame)  controller.Previous();
    }
}