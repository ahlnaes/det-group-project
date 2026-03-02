using System;
using UnityEngine;

public class AudioAnalyser : MonoBehaviour
{
    private const int FFTSize = 1024;
    private const int BANDCOUNT = 8;
    
    private float[] 
        _accumulationBuffer, 
        _windowCoefficients, 
        _windowedBuffer, 
        _frontBuffer, 
        _backBuffer;

    private int 
        _accumulationPos, 
        _backBufferIndex;
    
    private volatile float _rms; //volatile because of thread safety (two threads read this variable)
    
    private void Awake()
    {
        //init arrays
        _accumulationBuffer = new float[FFTSize];
        _windowCoefficients = new float[FFTSize];
        _windowedBuffer     = new float[FFTSize];
        _frontBuffer        = new float[BANDCOUNT];
        _backBuffer         = new float[BANDCOUNT];
        
        //init int
        _accumulationPos = 0;

        //calculate window coefficients
        //Hann formula: https://en.wikipedia.org/wiki/Hann_function
        for (int i = 0; i < FFTSize; i++)
        {
            _windowCoefficients[i] = 0.5f * (1f - Mathf.Cos(2f * Mathf.PI * i / (FFTSize - 1)));
        }
    }

    // Unity calls OnAudioFilterRead on the DSP thread every time anew audio buffer is ready to process
    private void OnAudioFilterRead(float[] data, int channels)
    {
        float sum = 0;
        for (int i = 0; i < data.Length; i += channels)
        {
            _accumulationBuffer[_accumulationPos] = data[i];
            _accumulationPos++;
            sum += data[i] * data[i];
            if (_accumulationPos < FFTSize)
            {
                return;
            }
        }
    }
    
    
}
