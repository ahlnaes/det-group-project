using UnityEngine;

public class LightFadeOut : MonoBehaviour
{
    [SerializeField] private Light[] lights;
    [SerializeField] private float fadeDuration = 5f;

    private float[] _startIntensities;
    private float _timer;
    private bool _fading;

    public void StartFade()
    {
        _startIntensities = new float[lights.Length];
        for (int i = 0; i < lights.Length; i++)
            _startIntensities[i] = lights[i].intensity;

        _timer = 0f;
        _fading = true;
    }

    void Update()
    {
        if (!_fading) return;

        _timer += Time.deltaTime;
        float t = Mathf.Clamp01(_timer / fadeDuration);

        for (int i = 0; i < lights.Length; i++)
            lights[i].intensity = Mathf.Lerp(_startIntensities[i], 0f, t);

        if (t >= 1f)
            _fading = false;
    }
}