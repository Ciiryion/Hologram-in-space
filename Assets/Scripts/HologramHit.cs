using UnityEngine;
using System.Collections;

public class HologramHit : MonoBehaviour
{
    public float hitDuration = 0.5f; // Durée de l'effet visuel
    private Renderer _rend;
    private float _currentStrength = 0f;

    void Start()
    {
        _rend = GetComponent<Renderer>();
    }

    private void OnCollisionEnter(Collision collision)
    {
        ContactPoint contact = collision.contacts[0];

        StopAllCoroutines();
        StartCoroutine(AnimateHit(contact.point));
    }

    IEnumerator AnimateHit(Vector3 position)
    {
        _rend.material.SetVector("_HitPosition", position);

        float t = 0f;

        while(t < hitDuration)
        {
            t += Time.deltaTime;
            _currentStrength = Mathf.Lerp(1f, 0f, t / hitDuration);
            _rend.material.SetFloat("_HitStrength", _currentStrength);
            yield return null;
        }

        _rend.material.SetFloat("_HitStrength", 0f);
    }
}
