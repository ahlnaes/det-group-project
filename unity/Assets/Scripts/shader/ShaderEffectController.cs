using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Serialization;

public class ShaderEffectController : MonoBehaviour
{
    [SerializeField] private int effectCount = 2; // how many different types of shaders
    [SerializeField] private int startingEffect = 0;
    
    // UnityEvents to change between effects, can hook up to anything, keyboard, button, tangible etc
    public UnityEvent onEffectSwitchStarted;
    public UnityEvent onEffectSwitchCompleted;

    private float _startBlend;
    private float _targetBlend;
    private float _crossfadeDuration;
    private float _crossfadeTimer;
    private bool  _isCrossfading;

    public float CurrentBlend { private set; get; }
    public int   CurrentEffect => Mathf.RoundToInt(CurrentBlend);

    private void Start()
    {
        SwitchTo(startingEffect);
    }

    private void Update()
    {
        if (!_isCrossfading) return;
        
        _crossfadeTimer += Time.deltaTime;
        
        //lerp from start to target over duration
        var t = Mathf.Clamp01(_crossfadeTimer / _crossfadeDuration);
        CurrentBlend = Mathf.Lerp(_startBlend, _targetBlend, t);
        Shader.SetGlobalFloat("_EffectBlend", CurrentBlend);

        if (t >= 1f)
        {
            CurrentBlend = _targetBlend;
            _isCrossfading = false;
            onEffectSwitchCompleted?.Invoke();
        }
    }
    
    // public api
    // duration = 0 -> hard cut, duration > 0 -> crossfade over N sec

    public void SwitchTo(int effectIndex, float duration = 0f)
    {
        // clamp to working valid range
        effectIndex = Mathf.Clamp(effectIndex, 0, effectCount - 1);
        _startBlend = CurrentBlend;
        _targetBlend = effectIndex;

        if (duration <= 0f)
        {
            //hard cut from one effect to another
            CurrentBlend = _targetBlend;
            _isCrossfading = false;
            Shader.SetGlobalFloat("_EffectBlend",  CurrentBlend);
        }
        else
        {
            //crossfade between effects
            _crossfadeDuration = duration;
            _crossfadeTimer = 0f;
            _isCrossfading = true;
        }
        onEffectSwitchStarted?.Invoke();
    }
    
    // utility/convenience methods
    public void NextEffect(float duration = 0f) => SwitchTo((CurrentEffect + 1) % effectCount, duration);
    public void PreviousEffect(float duration = 0f) =>  SwitchTo((CurrentEffect - 1) % effectCount, duration);
    public void NextEffectCrossfade() => NextEffect(1f);
    public void PreviousEffectCrossfade() => PreviousEffect(1f);
}
