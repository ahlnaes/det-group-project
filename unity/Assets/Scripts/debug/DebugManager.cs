using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace debug
{
    [System.Serializable]
    public class DebugObject
    {
        public GameObject gameObject;
        public bool active;
    }

    public class DebugManager : MonoBehaviour
    {
        [Header("Debug Objects")]
        [Header("Add GameObject used for debug and set active/not active")]
        [Space]
        public List<DebugObject> debugObjects = new List<DebugObject>();

        private void Start()
        {
            ApplyStates();
        }

        private void ApplyStates()
        {
            foreach (var obj in debugObjects.Where(obj => obj.gameObject != null))
            {
                obj.gameObject.SetActive(obj.active);
            }
        }

        private void OnValidate()
        {
            ApplyStates();
        }
    }
}