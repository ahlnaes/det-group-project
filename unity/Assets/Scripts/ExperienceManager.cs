using UnityEngine;

public class ExperienceManager : MonoBehaviour
{
    [Header("Audio Source")]
    public GameObject audioAnalyser;
    [Header("Shader Effect Controller")]
    public GameObject shaderEffectController;
    
    private AudioSource _audioSource;
    private ShaderEffectController _shaderEffectController;
    void Start()
    {
        _audioSource = audioAnalyser.GetComponent<AudioSource>();
        _shaderEffectController = shaderEffectController.GetComponent<ShaderEffectController>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void StartExperience()
    {
        _audioSource.Play();
        _shaderEffectController.SwitchTo(1);
    }
}
