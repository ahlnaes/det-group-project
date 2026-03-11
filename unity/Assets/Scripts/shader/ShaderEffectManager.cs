using System;
using System.Collections.Generic;
using UnityEngine;

namespace shader
{
    // Not a MonoBehaviour — just a serializable data+logic container
// [System.Serializable] makes it show up in the Inspector as a list entry
    [System.Serializable]
    public class ShaderEffect
    {
        public string label; // e.g. "Walls", "Floor" — just for Inspector readability
        public Renderer targetRenderer;
        public Material[] effects;
        public int startingEffect = 0;

        // Not serialized — runtime state only
        [HideInInspector] public int currentEffect;

        public void Initialize() => SwitchTo(startingEffect);

        public void SwitchTo(int index)
        {
            if (effects == null || effects.Length == 0 || targetRenderer == null) return;
            currentEffect = Mathf.Clamp(index, 0, effects.Length - 1);
            targetRenderer.material = effects[currentEffect];
        }

        public void Next() => SwitchTo((currentEffect + 1) % effects.Length);
        public void Previous() => SwitchTo((currentEffect - 1 + effects.Length) % effects.Length);
    }

    public class ShaderEffectManager : MonoBehaviour
    {
        [Header("Shader Effects")]
        public List<ShaderEffect> effects = new List<ShaderEffect>();

        void Start()
        {
            foreach (ShaderEffect effect in effects)
                effect.Initialize();
        }

        public void Next()
        {
            foreach (ShaderEffect effect in effects) effect.Next();
        }

        public void Previous()
        {
            foreach (ShaderEffect effect in effects) effect.Previous();
        }

        public void SwitchTo(int materialIndex)
        {
            foreach (ShaderEffect effect in effects) effect.SwitchTo(materialIndex);
        }
    }
}