using shader;
using UnityEngine;

public class ExperienceManager : MonoBehaviour
{
    [Header("Audio Source")]
    public GameObject audioAnalyser;
    [Header("Shader Effect Controller")]
    public GameObject shaderEffectController;
    [Header("Lights Controller")]
    public GameObject lightsController;
    
    private AudioSource _audioSource;
    private ShaderEffectManager _shaderEffectManager;
    private LightFadeOut _lightFadeOut;
    void Start()
    {
        _audioSource = audioAnalyser.GetComponent<AudioSource>();
        _shaderEffectManager = shaderEffectController.GetComponent<ShaderEffectManager>();
        _lightFadeOut = lightsController.GetComponent<LightFadeOut>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void StartExperience()
    {
        _audioSource.Play();
        _shaderEffectManager.SwitchTo(1);
    }
}
