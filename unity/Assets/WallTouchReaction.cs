using UnityEngine;
using Oculus.Interaction;

public class WallTouchReaction : MonoBehaviour
{
    private Renderer rend;
    private Color originalColor;
    public Color touchedColor = Color.red;

    private AudioSource audioSource;

    void Start()
    {
        rend = GetComponent<Renderer>();
        originalColor = rend.material.color;
        audioSource = GetComponent<AudioSource>();
    }

    public void OnPoke()
    {
        rend.material.color = touchedColor;

        if (audioSource != null)
            audioSource.Play();
    }

    public void OnPokeEnd()
    {
        rend.material.color = originalColor;
    }
}