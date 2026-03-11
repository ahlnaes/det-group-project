using UnityEngine;
using Oculus.Interaction;

public class HeartStep : MonoBehaviour
{
    public GameObject connector;
    public GameObject buttonVisual;

    public PokeInteractable pokeInteractable;

    public GameObject nextStepObject;

    private HeartStep nextStep;
    private bool completed = false;

    private void Awake()
    {
        if (nextStepObject != null)
        {
            nextStep = nextStepObject.GetComponent<HeartStep>();
        }

        if (pokeInteractable == null)
        {
            pokeInteractable = GetComponent<PokeInteractable>();
        }
    }

    private void Start()
    {
        if (connector != null)
            connector.SetActive(false);

        if (nextStep != null)
            nextStep.DisableStep();
    }

    public void PressStep()
    {
        if (completed) return;

        completed = true;

        if (connector != null)
            connector.SetActive(true);

        if (buttonVisual != null)
            buttonVisual.SetActive(false);

        DisableStep();

        if (nextStep != null)
            nextStep.EnableStep();
    }

    public void EnableStep()
    {
        if (pokeInteractable != null)
            pokeInteractable.enabled = true;
    }

    public void DisableStep()
    {
        if (pokeInteractable != null)
            pokeInteractable.enabled = false;
    }
}