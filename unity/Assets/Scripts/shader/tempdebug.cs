using UnityEngine;

public class tempdebug : MonoBehaviour
{
    void Start()
    {
        Mesh mesh = GetComponent<MeshFilter>().mesh;
        float maxR = 0;
        float maxY = float.MinValue;
        Vector3 maxRVert = Vector3.zero;
        Vector3 maxYVert = Vector3.zero;
    
        foreach (Vector3 v in mesh.vertices)
        {
            Vector3 w = transform.TransformPoint(v);
            float r = Mathf.Sqrt(w.x * w.x + w.z * w.z);
            if (r > maxR) { maxR = r; maxRVert = w; }
            if (w.y > maxY) { maxY = w.y; maxYVert = w; }
        }
        Debug.Log($"Max radial vertex: {maxRVert}, r={maxR}");
        Debug.Log($"Max Y vertex: {maxYVert}, y={maxY}");
    }
}
