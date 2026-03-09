using UnityEngine;

public class ShaderEffectController : MonoBehaviour
{
    [SerializeField] private Renderer targetRenderer;
    [SerializeField] private Material[] effects;
    [SerializeField] private int startingEffect = 0;

    public int CurrentEffect { get; private set; }

    void Start() => SwitchTo(startingEffect);

    public void SwitchTo(int index)
    {
        CurrentEffect = Mathf.Clamp(index, 0, effects.Length - 1);
        targetRenderer.material = effects[CurrentEffect];
    }

    public void NextEffect() => SwitchTo((CurrentEffect + 1) % effects.Length);
    public void PreviousEffect() => SwitchTo((CurrentEffect - 1 + effects.Length) % effects.Length);
}